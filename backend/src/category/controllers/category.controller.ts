import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common';
import { CategoryService } from '../services/category.service';
import { CreateCategoryDto } from '../dtos/category.dto';
import { UseToken } from 'src/auth/decorator/userToken.decorator';
import { AdminTypeGuard } from 'src/users/guards/user.guard';

@Controller('categories')
export class CategoryController {
  constructor(private readonly categoryService: CategoryService) {}

  @Post('create')
  @UseToken()
  @UseGuards(AdminTypeGuard)
  create(@Body() createCategoryDto: CreateCategoryDto) {
    return this.categoryService.create(createCategoryDto);
  }

  @Get('all')
  @UseToken()
  findAll() {
    return this.categoryService.findAll();
  }

  @Get('view/:id')
  @UseToken()
  findOne(@Param('id') id: string) {
    return this.categoryService.findOne(id);
  }
}
