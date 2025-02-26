import { Injectable } from '@nestjs/common';
import { CreateUserDto } from './dto/create-user.dto';
import { PrismaService } from 'nestjs-prisma';

import { User } from '@prisma/client';
import { UpdateUsernameDto } from './dto/update-username.dto';
import { UpdateAvatarDto } from './dto/update-avatar.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async create(data: CreateUserDto): Promise<User> {
    const { address, email, username } = data;

    const newUser = await this.prisma.user.create({
      data: {
        address,
        email,
        username,
      },
    });

    return newUser;
  }

  async findAll() {
    return this.prisma.user.findMany();
  }

  async findOne(id: string) {
    return this.prisma.user.findUnique({
      where: {
        id,
      },
    });
  }

  async findOneByAddress(address: string) {
    return this.prisma.user.findUnique({
      where: {
        address,
      },
    });
  }

  remove(id: number) {
    return `This action removes a #${id} user`;
  }

  async updateUsername(
    userId: string,
    updateUsernameDto: UpdateUsernameDto,
  ): Promise<User> {
    const { username, picture } = updateUsernameDto;

    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: {
        username,
        picture,
      },
    });

    return updatedUser;
  }

  async updateAvatar(
    userId: string,
    updateAvatarDto: UpdateAvatarDto,
  ): Promise<User> {
    const { picture } = updateAvatarDto;
    const updatedUser = await this.prisma.user.update({
      where: { id: userId },
      data: {
        picture,
      },
    });

    return updatedUser;
  }

  async findOneByUsername(username: string) {
    return this.prisma.user.findUnique({
      where: {
        username,
      },
    });
  }
}
