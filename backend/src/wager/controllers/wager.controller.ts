import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common';
import { WagerService } from '../services/wager.service';
import { CreateWagerDto } from '../dtos/wager.dto';
import { CreateWagerGuard } from '../guards/wager.guard';
import { UseToken } from 'src/auth/decorator/userToken.decorator';

@Controller('wagers')
export class WagerController {
  constructor(private readonly wagerService: WagerService) {}

  @Post('create')
  @UseToken()
  @UseGuards(CreateWagerGuard)
  create(@Body() data: CreateWagerDto) {
    return this.wagerService.createWager(data);
  }

  @Get('all')
  @UseToken()
  findAll() {
    return this.wagerService.getAllWagers();
  }

  @Get('view/:id')
  @UseToken()
  findOne(@Param('id') id: string) {
    return this.wagerService.findOneById(id);
  }
}
